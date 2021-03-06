# DownloadManager
基于NSURLSessionDataTask的前台下载 + 断点续传

IOS7之后，大家都开始用NSURLSession来处理下载了，AFNetworking SDImage等第三方库也改成了这种方式
先说后台下载：

1. 在没有特别关注的情况下，可能很多开发者使用afnetworking下载的姿势并没有考虑到后台下载这一块。在默认情况（不做特别设置）下，afnetworking并未启用backgroundsession, 因此很可能你的app是不支持后台下载的。

2. nsurlsession对后台下载的支持主要通过 backgroundSessionConfiguration/backgroundSessionConfigurationWithIdentifier 类型的session来支持；通过该session来调用下载方法，实现几个下载相关的回调方法，也就可以实现基本的目的：应用切换到后台时仍然在下载（但下载完成后得不到回调和提醒）

此文不讨论后台模式的下载，其实backgroundSession模式，当你启动一个downloadTask之后，是系统另外开辟了一个新的进程来进行下载，跟你app本身是否前台、是否挂起、是否已经关掉都没有关系了，当任务在后台下载完成后会通知你的app----这才算真正的后台模式下载，但这个模式有一个很坑爹的地方：当下载超时或是下载链接本身就是一个无效链接，或是因为手机系统任务调度，或是因为下载服务器的原因导致的超时，这种模式都不会回调响应的代理方法，会在UI层面产生很久下载不动的状态，但又不提示超时，这是因为：
“从iOS8开始，如果服务器没有响应，则后台模式下的NSUrlSession不会调用此委托方法。 -(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
下载/上传无限期保持空闲状态。 当服务器没有响应时，在iOS7上调用此委托时出错”
“通常，NSURLSession后台会话不会使任务失败   电线出了问题。相反，它继续寻找一个   是时候运行请求并重试了。这继续下去   直到资源超时到期（即，值的   NSURLSessionConfiguration中的timeoutIntervalForResource属性   用于创建会话的对象）。当前的默认值   价值是一周！”
“换句话说，iOS7中超时失败的行为是不正确的。在后台会话的上下文中，由于网络问题而不立即失败更有意思。因此，自iOS8以来，NSURLSession任务即使遇到超时和网络丢失也会继续。但它会一直持续到达timeoutIntervalForResource。

所以基本上timeoutIntervalForRequest在后台会话中不起作用，但是timeoutIntervalForResource会起作用”
“timeoutIntervalForResource指整个任务完成的最大时间，简单讲就是 NSURLSession 里面所有 task 完成的总时间(包括因控制最大并发数而排队等待的时间)”

因此，backgroundSession模式及时有如此多优点，但针对这个问题很影响用户体验

所以还是回到当初NSURLConnection的类似模式，采用NSURLSessionDataTask来处理下载数据！

为什么不用NSURLSessionDownloadTask？
是因为NSURLSessionDownloadTask在下载过程中压根不告诉你当前临时文件保存的路径，只有当整个下载完成时才告诉你文件放哪儿的！有朋友说：不是有个resumeData吗，调用task的cancelByProducingResumeData方法获取这个resumeData 然后用这个data重启任务呀！
我想问，你在什么时机调用cancelByProducingResumeData方法呢？ 下载进度回调方法里？应用退到后台的通知回调里？这都是坑啊！
应用在退到后台后还是稍微执行一点时间，这段时间还是在继续下载数据的，这个resumeData压根就没有比能直接拿到下载的半截文件的大小来的准、来的狠！！


参考：https://blog.csdn.net/hongfengkt/article/details/48290561
https://juejin.im/entry/588477782f301e0069826b2b
https://www.jianshu.com/p/5a07352e9473
http://zxfcumtcs.github.io/2016/06/09/NSURLSession_Supplements/
http://landcareweb.com/questions/24449/shi-yong-hou-tai-pei-zhi-shi-nsurlsessiontaskzai-chao-shi-hou-yong-yuan-bu-hui-hui-diao
